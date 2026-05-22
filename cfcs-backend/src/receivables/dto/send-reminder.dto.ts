import { IsIn, IsOptional } from 'class-validator';

export class SendReminderDto {
  @IsOptional()
  @IsIn(['polite', 'firm'])
  tone?: 'polite' | 'firm';
}