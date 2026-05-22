import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Receivable } from './entities/receivable.entity';
import { CreateReceivableDto } from './dto/create-receivable.dto';
import { UpdateReceivableDto } from './dto/update-receivable.dto';
import { ReceivableStatus } from './enums/receivable-status.enum';
import { UpdateDueDateDto } from './dto/update-due-date.dto';
import { ConflictException } from '@nestjs/common';
import { SendReminderDto } from './dto/send-reminder.dto';
import { MarkPaidDto } from './dto/mark-paid.dto';
import { Reminder } from '../notifications/entities/reminder.entity';
import { Document } from '../documents/entities/document.entity';
import { InvoiceService } from '../documents/invoice.service';

@Injectable()
export class ReceivablesService {
  constructor(
    @InjectRepository(Receivable)
    private readonly receivableRepository: Repository<Receivable>,

    @InjectRepository(Reminder)
    private readonly reminderRepository: Repository<Reminder>,

    @InjectRepository(Document)
    private readonly documentRepository: Repository<Document>,

    private readonly invoiceService: InvoiceService,
  ) {}

  async create(userId: string, dto: CreateReceivableDto) {
    const receivable = this.receivableRepository.create({
      ...dto,
      userId,
      amountPaid: 0,
      balanceAmount: dto.totalAmount,
      status: ReceivableStatus.PENDING,
    });

    const savedReceivable = await this.receivableRepository.save(receivable);

    const fullReceivable = await this.receivableRepository.findOne({
      where: {
        id: savedReceivable.id,
      },
      relations: ['customer'],
    });

    const fileName = await this.invoiceService.generateInvoice(
      fullReceivable,
      fullReceivable!.customer,
    );

    const document = this.documentRepository.create({
      receivableId: savedReceivable.id,
      fileName: fileName,
      filePath: fileName,
      mimeType: 'application/pdf',
    });

    await this.documentRepository.save(document);

    return {
      success: true,
      data: savedReceivable,
    };
  }

  async findAll(userId: string, customerId?: string) {
    const where: any = {
      userId,
      deletedAt: null,
    };

    if (customerId) {
      where.customerId = customerId;
    }

    const receivables = await this.receivableRepository.find({
      where,
      relations: ['customer'],
      order: { createdAt: 'DESC' },
    });

    const today = new Date();

    for (const receivable of receivables) {
      if (
        new Date(receivable.dueDate) < today &&
        receivable.status !== ReceivableStatus.PAID
      ) {
        receivable.status = ReceivableStatus.OVERDUE;
      }
    }

    return {
      success: true,
      data: receivables,
    };
  }

  async findOne(userId: string, id: string) {
    const receivable = await this.receivableRepository.findOne({
      where: { id, userId },
      relations: ['customer'],
    });

    if (!receivable) {
      throw new NotFoundException('Receivable not found');
    }

    return { success: true, data: receivable };
  }

  async update(userId: string, id: string, dto: UpdateReceivableDto) {
    const receivable = await this.receivableRepository.findOne({
      where: { id, userId },
    });

    if (!receivable) {
      throw new NotFoundException('Receivable not found');
    }

    Object.assign(receivable, dto);

    const totalAmount = Number(receivable.totalAmount);
    const amountPaid = Number(receivable.amountPaid);

    if (totalAmount < amountPaid) {
      throw new BadRequestException(
        'Total amount cannot be less than amount already paid',
      );
    }

    receivable.balanceAmount = totalAmount - amountPaid;

    if (receivable.balanceAmount === 0) {
      receivable.status = ReceivableStatus.PAID;
      receivable.isArchived = true;
    } else if (amountPaid > 0) {
      receivable.status = ReceivableStatus.PARTIALLY_PAID;
      receivable.isArchived = false;
    } else {
      const today = new Date();
      receivable.status =
        new Date(receivable.dueDate) < today
          ? ReceivableStatus.OVERDUE
          : ReceivableStatus.PENDING;
      receivable.isArchived = false;
    }

    return {
      success: true,
      data: await this.receivableRepository.save(receivable),
    };
  }

  async updateDueDate(id: string, userId: string, dto: UpdateDueDateDto) {
    const receivable = await this.receivableRepository.findOne({
      where: { id, userId },
    });

    if (!receivable) {
      throw new NotFoundException('Receivable not found');
    }

    // ✅ Update due date
    receivable.dueDate = new Date(dto.dueDate);

    // 🔥 Recalculate status
    const today = new Date();

    if (receivable.status !== ReceivableStatus.PAID) {
      if (new Date(dto.dueDate) < today) {
        receivable.status = ReceivableStatus.OVERDUE;
      } else if (Number(receivable.amountPaid) > 0) {
        receivable.status = ReceivableStatus.PARTIALLY_PAID;
      } else {
        receivable.status = ReceivableStatus.PENDING;
      }
    }

    return this.receivableRepository.save(receivable);
  }

  async findHistory(userId: string) {
    const receivables = await this.receivableRepository.find({
      where: {
        userId,
        isArchived: true,
      },
      relations: ['customer'],
      order: { createdAt: 'DESC' },
    });

    return {
      success: true,
      data: receivables,
    };
  }

  async restore(id: string, userId: string) {
    const receivable = await this.receivableRepository.findOne({
      where: { id, userId },
    });

    if (!receivable) {
      throw new NotFoundException('Receivable not found');
    }

    receivable.isArchived = false;

    return this.receivableRepository.save(receivable);
  }

  async remove(userId: string, id: string) {
    const receivable = await this.receivableRepository.findOne({
      where: { id, userId },
    });

    if (!receivable) {
      throw new NotFoundException('Receivable not found');
    }

    receivable.isArchived = true;
    await this.receivableRepository.save(receivable);

    return { success: true };
  }

  async sendReminder(id: string, userId: string, dto: SendReminderDto) {
    const receivable = await this.receivableRepository.findOne({
      where: {
        id,
        userId,
      },
      relations: ['customer'],
    });

    if (!receivable) {
      throw new NotFoundException('Receivable not found');
    }

    if (receivable.status === ReceivableStatus.PAID) {
      throw new ConflictException('Receivable already paid');
    }

    if (!receivable.customer.phone) {
      throw new ConflictException('Customer phone missing');
    }

    const tone = dto.tone || 'polite';

    let message = '';

    if (tone == 'firm') {
      message =
        `Reminder: ₹${receivable.balanceAmount} is overdue. ` +
        `Please make payment immediately.`;
    } else {
      message =
        `Hello ${receivable.customer.name}, ` +
        `this is a gentle reminder for pending payment of ₹${receivable.balanceAmount}.`;
    }

    const whatsAppUrl =
      `https://wa.me/91${receivable.customer.phone}` +
      `?text=${encodeURIComponent(message)}`;

    receivable.reminderCount += 1;
    receivable.lastReminderDate = new Date();

    await this.receivableRepository.save(receivable);

    const reminder = this.reminderRepository.create({
      userId,
      receivableId: receivable.id,
      tone,
      sentAt: new Date(),
    });

    await this.reminderRepository.save(reminder);

    return {
      success: true,
      data: {
        whatsAppUrl,
        reminderCount: receivable.reminderCount,
      },
    };
  }

  async markPaid(id: string, userId: string, dto: MarkPaidDto) {
    const receivable = await this.receivableRepository.findOne({
      where: {
        id,
        userId,
      },
    });

    if (!receivable) {
      throw new NotFoundException('Receivable not found');
    }

    if (receivable.status === ReceivableStatus.PAID) {
      throw new ConflictException('Receivable already paid');
    }

    const paymentAmount = Number(dto.amount);
    const currentBalance = Number(receivable.balanceAmount);
    const currentPaid = Number(receivable.amountPaid);

    // Cannot overpay
    if (paymentAmount > currentBalance) {
      throw new BadRequestException('Payment amount exceeds remaining balance');
    }

    // Update amounts
    receivable.amountPaid = currentPaid + paymentAmount;
    receivable.balanceAmount = currentBalance - paymentAmount;

    receivable.paidDate = dto.paidDate ? new Date(dto.paidDate) : new Date();

    receivable.paidNote = dto.note;

    // Full payment
    if (receivable.balanceAmount === 0) {
      receivable.status = ReceivableStatus.PAID;
      receivable.isArchived = true;
    }
    // Partial payment
    else {
      receivable.status = ReceivableStatus.PARTIALLY_PAID;
      receivable.isArchived = false;
    }

    await this.receivableRepository.save(receivable);

    return {
      success: true,
      data: {
        status: receivable.status,
        amountPaid: receivable.amountPaid,
        balanceAmount: receivable.balanceAmount,
      },
    };
  }

  async getFollowUp(userId: string) {
    const receivables = await this.receivableRepository.find({
      where: {
        userId,
        isArchived: false,
      },
      relations: ['customer'],
      order: { dueDate: 'ASC' },
    });

    const today = new Date();

    const isSameDay = (d1: Date, d2: Date) =>
      d1.toDateString() === d2.toDateString();

    const followUps = receivables.filter((r) => {
      const dueDate = new Date(r.dueDate);

      return (
        r.status !== ReceivableStatus.PAID &&
        (dueDate < today || isSameDay(dueDate, today))
      );
    });

    return {
      success: true,
      data: followUps.map((r) => {
        const dueDate = new Date(r.dueDate);
        const diffDays = Math.floor(
          (today.getTime() - dueDate.getTime()) / (1000 * 60 * 60 * 24),
        );

        return {
          id: r.id,
          customerName: r.customer.name,
          amount: r.balanceAmount,
          dueDate: r.dueDate,
          status: r.status,
          overdueDays: dueDate < today ? diffDays : 0,
        };
      }),
    };
  }
}
