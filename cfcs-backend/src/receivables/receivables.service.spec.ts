import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ReceivablesService } from './receivables.service';
import { Receivable } from './entities/receivable.entity';
import { Reminder } from '../notifications/entities/reminder.entity';
import { Document } from '../documents/entities/document.entity';
import { InvoiceService } from '../documents/invoice.service';

describe('ReceivablesService', () => {
  let service: ReceivablesService;

  beforeEach(async () => {
    const repository = {
      find: jest.fn(),
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReceivablesService,
        { provide: getRepositoryToken(Receivable), useValue: repository },
        { provide: getRepositoryToken(Reminder), useValue: repository },
        { provide: getRepositoryToken(Document), useValue: repository },
        {
          provide: InvoiceService,
          useValue: {
            generateInvoice: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<ReceivablesService>(ReceivablesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
