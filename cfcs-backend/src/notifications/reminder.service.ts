import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Receivable } from '../receivables/entities/receivable.entity';
import { ReceivableStatus } from '../receivables/enums/receivable-status.enum';

@Injectable()
export class ReminderService {
  private readonly logger = new Logger(ReminderService.name);

  constructor(
    @InjectRepository(Receivable)
    private readonly receivableRepo: Repository<Receivable>,
  ) {}

  @Cron('* * * * *')
  async handleReminders() {
    const today = new Date();

    const receivables = await this.receivableRepo.find({
      relations: ['customer'],
    });

    receivables.forEach((r) => {
      if (
        new Date(r.dueDate) < today &&
        r.balanceAmount > 0 &&
        r.status !== ReceivableStatus.PAID
      ) {
        this.logger.log(
          `Reminder: Collect Rs. ${r.balanceAmount} from ${r.customer.name}`,
        );
      }
    });
  }
}
