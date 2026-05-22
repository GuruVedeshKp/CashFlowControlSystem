import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Payment } from './entities/payment.entity';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { UpdatePaymentDto } from './dto/update-payment.dto';
import { Receivable } from '../receivables/entities/receivable.entity';
import { ReceivableStatus } from '../receivables/enums/receivable-status.enum';

@Injectable()
export class PaymentsService {
  constructor(
    @InjectRepository(Payment)
    private readonly paymentRepo: Repository<Payment>,

    @InjectRepository(Receivable)
    private readonly receivableRepo: Repository<Receivable>,
  ) {}

  async create(userId: string, dto: CreatePaymentDto) {
    const receivable = await this.receivableRepo.findOne({
      where: {
        id: dto.receivableId,
        userId,
      },
    });

    if (!receivable) {
      throw new NotFoundException('Receivable not found');
    }

    if (dto.amount > Number(receivable.balanceAmount)) {
      throw new BadRequestException('Payment exceeds remaining balance');
    }

    const payment = this.paymentRepo.create({
      userId,
      receivableId: dto.receivableId,
      amount: dto.amount,
      paymentDate: new Date(dto.paymentDate),
      note: dto.note,
    });

    await this.paymentRepo.save(payment);

    const newPaid = Number(receivable.amountPaid) + dto.amount;

    const newBalance = Number(receivable.balanceAmount) - dto.amount;

    receivable.amountPaid = newPaid;
    receivable.balanceAmount = newBalance;

    if (newBalance == 0) {
      receivable.status = ReceivableStatus.PAID;
      receivable.paidAt = new Date();
      receivable.isArchived = true;
    } else {
      receivable.status = ReceivableStatus.PARTIALLY_PAID;
    }

    await this.receivableRepo.save(receivable);

    return {
      success: true,
      data: {
        payment,
        receivable,
      },
    };
  }

  async findAll(userId: string, receivableId?: string) {
    const where: any = { userId };

    if (receivableId) {
      where.receivableId = receivableId;
    }

    const payments = await this.paymentRepo.find({
      where,
      relations: ['receivable'],
      order: {
        paymentDate: 'DESC',
      },
    });

    const totalPaid = payments.reduce(
      (sum, payment) => sum + Number(payment.amount),
      0,
    );

    return {
      success: true,
      totalPaid,
      data: payments,
    };
  }

  async update(userId: string, id: string, dto: UpdatePaymentDto) {
    const payment = await this.paymentRepo.findOne({
      where: { id, userId },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    const receivable = await this.receivableRepo.findOne({
      where: {
        id: payment.receivableId,
        userId,
      },
    });

    if (!receivable) {
      throw new NotFoundException('Receivable not found');
    }

    if (dto.receivableId && dto.receivableId !== payment.receivableId) {
      throw new BadRequestException(
        'Cannot move payment to another receivable',
      );
    }

    const nextAmount = dto.amount ?? Number(payment.amount);
    const otherPayments = await this.paymentRepo.find({
      where: {
        userId,
        receivableId: payment.receivableId,
      },
    });

    const nextPaidTotal = otherPayments.reduce((sum, item) => {
      if (item.id === payment.id) {
        return sum + Number(nextAmount);
      }

      return sum + Number(item.amount);
    }, 0);

    if (nextPaidTotal > Number(receivable.totalAmount)) {
      throw new BadRequestException('Payment total exceeds receivable amount');
    }

    payment.amount = nextAmount;

    if (dto.paymentDate !== undefined) {
      payment.paymentDate = new Date(dto.paymentDate);
    }

    if (dto.note !== undefined) {
      payment.note = dto.note;
    }

    await this.paymentRepo.save(payment);
    await this.recalculateReceivable(receivable);

    return {
      success: true,
      data: payment,
    };
  }

  async remove(userId: string, id: string) {
    const payment = await this.paymentRepo.findOne({
      where: { id, userId },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    const receivable = await this.receivableRepo.findOne({
      where: {
        id: payment.receivableId,
        userId,
      },
    });

    if (!receivable) {
      throw new NotFoundException('Receivable not found');
    }

    await this.paymentRepo.remove(payment);
    await this.recalculateReceivable(receivable);

    return { success: true };
  }

  private async recalculateReceivable(receivable: Receivable) {
    const payments = await this.paymentRepo.find({
      where: {
        userId: receivable.userId,
        receivableId: receivable.id,
      },
    });

    const totalPaid = payments.reduce(
      (sum, payment) => sum + Number(payment.amount),
      0,
    );

    const totalAmount = Number(receivable.totalAmount);

    if (totalPaid > totalAmount) {
      throw new BadRequestException('Payment total exceeds receivable amount');
    }

    receivable.amountPaid = totalPaid;
    receivable.balanceAmount = totalAmount - totalPaid;

    if (receivable.balanceAmount === 0) {
      receivable.status = ReceivableStatus.PAID;
      receivable.paidAt = new Date();
      receivable.isArchived = true;
    } else if (totalPaid > 0) {
      receivable.status = ReceivableStatus.PARTIALLY_PAID;
      receivable.paidAt = undefined;
      receivable.isArchived = false;
    } else {
      const today = new Date();
      const dueDate = new Date(receivable.dueDate);

      receivable.status =
        dueDate < today ? ReceivableStatus.OVERDUE : ReceivableStatus.PENDING;
      receivable.paidAt = undefined;
      receivable.isArchived = false;
    }

    await this.receivableRepo.save(receivable);
  }
}
