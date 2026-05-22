import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ReceivablesController } from './receivables.controller';
import { ReceivablesService } from './receivables.service';
import { Receivable } from './entities/receivable.entity';
import { Reminder } from '../notifications/entities/reminder.entity';
import { Document } from '../documents/entities/document.entity';
import { DocumentsModule } from '../documents/documents.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Receivable,
      Reminder,
      Document,
    ]),
    DocumentsModule,
  ],
  controllers: [ReceivablesController],
  providers: [ReceivablesService],
})
export class ReceivablesModule {}