import { Test, TestingModule } from '@nestjs/testing';
import { ReceivablesController } from './receivables.controller';
import { ReceivablesService } from './receivables.service';

describe('ReceivablesController', () => {
  let controller: ReceivablesController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ReceivablesController],
      providers: [
        {
          provide: ReceivablesService,
          useValue: {
            create: jest.fn(),
            findAll: jest.fn(),
            getFollowUp: jest.fn(),
            findHistory: jest.fn(),
            findOne: jest.fn(),
            update: jest.fn(),
            updateDueDate: jest.fn(),
            restore: jest.fn(),
            remove: jest.fn(),
            sendReminder: jest.fn(),
            markPaid: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<ReceivablesController>(ReceivablesController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
