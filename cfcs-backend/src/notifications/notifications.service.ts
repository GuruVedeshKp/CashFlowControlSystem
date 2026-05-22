import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Reminder } from './entities/reminder.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Reminder)
    private readonly reminderRepo: Repository<Reminder>,
  ) {}

  async getReminderHistory(userId: string) {
    const reminders = await this.reminderRepo.find({
      where: { userId },
      relations: ['receivable', 'receivable.customer'],
      order: {
        createdAt: 'DESC',
      },
    });

    return {
      success: true,
      data: reminders,
    };
  }
}