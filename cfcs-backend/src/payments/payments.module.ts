import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PaymentsService } from './payments.service';
import { PaymentsController } from './payments.controller';
import { Payment } from './entities/payment.entity';
import { Receivable } from '../receivables/entities/receivable.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Payment, Receivable])],
  providers: [PaymentsService],
  controllers: [PaymentsController],
})
export class PaymentsModule {}