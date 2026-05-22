import {
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { Document } from './entities/document.entity';
import { Receivable } from '../receivables/entities/receivable.entity';
import * as fs from 'fs';

@Injectable()
export class DocumentsService {
  constructor(
    @InjectRepository(Document)
    private readonly documentRepository: Repository<Document>,

    @InjectRepository(Receivable)
    private readonly receivableRepository: Repository<Receivable>,
  ) {}

  async uploadDocument(
    userId: string,
    receivableId: string,
    file: Express.Multer.File,
  ) {
    const receivable =
      await this.receivableRepository.findOne({
        where: {
          id: receivableId,
          userId,
        },
      });

    if (!receivable) {
      throw new NotFoundException(
        'Receivable not found',
      );
    }

    const document =
      this.documentRepository.create({
        receivableId,
        fileName: file.originalname,
        filePath: file.filename,
        mimeType: file.mimetype,
        fileSize: file.size,
        storageProvider: 'basic',
      });

    return {
      success: true,
      data:
          await this.documentRepository.save(
        document,
      ),
    };
  }

  async getDocuments(
    userId: string,
    receivableId: string,
  ) {
    const receivable =
      await this.receivableRepository.findOne({
        where: {
          id: receivableId,
          userId,
        },
      });

    if (!receivable) {
      throw new NotFoundException(
        'Receivable not found',
      );
    }

    const documents =
        await this.documentRepository.find({
      where: {
        receivableId,
        deletedAt: IsNull(),
      },
      order: {
        uploadedAt: 'DESC',
      },
    });

    return {
      success: true,
      data: documents,
    };
  }

  async deleteDocument(
    userId: string,
    documentId: string,
  ) {
    const document =
      await this.documentRepository.findOne({
        relations: ['receivable'],
        where: {
          id: documentId,
          deletedAt: IsNull(),
        },
      });

    if (
      !document ||
      document.receivable.userId !== userId
    ) {
      throw new NotFoundException(
        'Document not found',
      );
    }

    const fullPath =
      `uploads/${document.filePath}`;

    if (fs.existsSync(fullPath)) {
      fs.unlinkSync(fullPath);
    }

    await this.documentRepository.softRemove(
      document,
    );

    return {
      success: true,
    };
  }
}