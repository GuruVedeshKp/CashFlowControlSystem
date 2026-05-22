import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { Document } from './entities/document.entity';
import { DocumentsService } from './documents.service';
import { DocumentsController } from './documents.controller';
import { InvoiceService } from './invoice.service';

import { BusinessProfile } from '../settings/entities/business-profile.entity';
import { Receivable } from '../receivables/entities/receivable.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Document,
      BusinessProfile,
      Receivable,
    ]),
  ],
  providers: [
    DocumentsService,
    InvoiceService,
  ],
  controllers: [
    DocumentsController,
  ],
  exports: [
    DocumentsService,
    InvoiceService,
  ],
})
export class DocumentsModule {}