import {
  Controller,
  Post,
  Get,
  Delete,
  Param,
  Req,
  UseGuards,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DocumentsService } from './documents.service';
import { diskStorage } from 'multer';
import * as path from 'path';

@Controller('api/v1')
@UseGuards(JwtAuthGuard)
export class DocumentsController {
  constructor(
    private readonly documentsService: DocumentsService,
  ) {}

  @Post('receivables/:id/documents')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: './uploads',
        filename: (_, file, callback) => {
          const uniqueName =
            Date.now() +
            '-' +
            Math.round(Math.random() * 1e9) +
            path.extname(file.originalname);

          callback(null, uniqueName);
        },
      }),
      fileFilter: (_, file, callback) => {
        const allowed = [
          'application/pdf',
          'image/jpeg',
          'image/png',
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ];

        callback(
          null,
          allowed.includes(file.mimetype),
        );
      },
    }),
  )
  uploadDocument(
    @Req() req,
    @Param('id') receivableId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.documentsService.uploadDocument(
      req.user.userId,
      receivableId,
      file,
    );
  }

  @Get('receivables/:id/documents')
  getDocuments(
    @Req() req,
    @Param('id') receivableId: string,
  ) {
    return this.documentsService.getDocuments(
      req.user.userId,
      receivableId,
    );
  }

  @Delete('documents/:documentId')
  deleteDocument(
    @Req() req,
    @Param('documentId') documentId: string,
  ) {
    return this.documentsService.deleteDocument(
      req.user.userId,
      documentId,
    );
  }
}