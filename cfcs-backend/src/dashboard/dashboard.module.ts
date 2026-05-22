import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DashboardService } from './dashboard.service';
import { DashboardController } from './dashboard.controller';
import { Receivable } from '../receivables/entities/receivable.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Receivable])],
  controllers: [DashboardController],
  providers: [DashboardService],
})
export class DashboardModule {}