import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Customer } from './entities/customer.entity';
import { Receivable } from '../receivables/entities/receivable.entity';
import { Payment } from '../payments/entities/payment.entity';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { UpdateCustomerDto } from './dto/update-customer.dto';

@Injectable()
export class CustomersService {
  constructor(
    @InjectRepository(Customer)
    private readonly customerRepository: Repository<Customer>,

    @InjectRepository(Receivable)
    private readonly receivableRepository: Repository<Receivable>,

    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
  ) {}

  async create(userId: string, dto: CreateCustomerDto) {
    const existing = await this.customerRepository.findOne({
      where: { userId, phone: dto.phone },
    });

    if (existing) {
      throw new ConflictException(
        'Customer with this phone already exists',
      );
    }

    const customer = this.customerRepository.create({
      ...dto,
      userId,
    });

    return {
      success: true,
      data: await this.customerRepository.save(customer),
    };
  }

  async findAll(userId: string) {
    const customers = await this.customerRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });

    return {
      success: true,
      data: customers,
    };
  }

  async findOne(userId: string, id: string) {
    const customer = await this.customerRepository.findOne({
      where: { id, userId },
    });

    if (!customer) {
      throw new NotFoundException('Customer not found');
    }

    return {
      success: true,
      data: customer,
    };
  }

  async update(
    userId: string,
    id: string,
    dto: UpdateCustomerDto,
  ) {
    const customer = await this.findOne(userId, id);

    Object.assign(customer.data, dto);

    await this.customerRepository.save(customer.data);

    return {
      success: true,
      data: customer.data,
    };
  }

  async remove(userId: string, id: string) {
    const customer = await this.findOne(userId, id);

    await this.customerRepository.softRemove(customer.data);

    return {
      success: true,
    };
  }

  async getCustomerHistory(
    userId: string,
    customerId: string,
  ) {
    const customer = await this.customerRepository.findOne({
      where: {
        id: customerId,
        userId,
      },
    });

    if (!customer) {
      throw new NotFoundException('Customer not found');
    }

    const receivables =
      await this.receivableRepository.find({
        where: {
          userId,
          customerId,
        },
        order: {
          createdAt: 'DESC',
        },
      });

    const history = await Promise.all(
      receivables.map(async (receivable) => {
        const payments =
          await this.paymentRepository.find({
            where: {
              userId,
              receivableId: receivable.id,
            },
            order: {
              paymentDate: 'DESC',
            },
          });

        return {
          receivable,
          payments,
        };
      }),
    );

    return {
      success: true,
      data: {
        customer,
        history,
      },
    };
  }
}