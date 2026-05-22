import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Receivable } from '../receivables/entities/receivable.entity';
import { ReceivableStatus } from '../receivables/enums/receivable-status.enum';

@Injectable()
export class DashboardService {
  constructor(
    @InjectRepository(Receivable)
    private readonly receivableRepo: Repository<Receivable>,
  ) {}

  async getSummary(userId: string) {
    const receivables = await this.receivableRepo.find({
      where: { userId, isArchived: false },
    });

    const today = new Date();

    const isSameDay = (d1: Date, d2: Date) =>
      d1.toDateString() === d2.toDateString();

    const isWithinNext7Days = (date: Date) => {
      const diff = (date.getTime() - today.getTime()) / (1000 * 60 * 60 * 24);
      return diff >= 0 && diff <= 7;
    };

    // ✅ Total Receivable
    const totalReceivable = receivables.reduce(
      (sum, r) => sum + Number(r.balanceAmount),
      0,
    );

    // ✅ Overdue
    const overdueAmount = receivables
      .filter(
        (r) =>
          new Date(r.dueDate) < today &&
          r.status !== ReceivableStatus.PAID,
      )
      .reduce((sum, r) => sum + Number(r.balanceAmount), 0);

    // ✅ Due Today
    const dueTodayAmount = receivables
      .filter((r) => isSameDay(new Date(r.dueDate), today))
      .reduce((sum, r) => sum + Number(r.balanceAmount), 0);

    // ✅ Expected This Week
    const expectedThisWeekAmount = receivables
      .filter((r) => isWithinNext7Days(new Date(r.dueDate)))
      .reduce((sum, r) => sum + Number(r.balanceAmount), 0);

    return {
      success: true,
      data: {
        cashSummary: {
          totalReceivable,
          overdueAmount,
          dueTodayAmount,
          expectedThisWeekAmount,
        },
      },
    };
  }
}