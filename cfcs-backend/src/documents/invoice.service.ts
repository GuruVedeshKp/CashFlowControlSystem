import {
  Injectable,
} from '@nestjs/common';
import PDFDocument from 'pdfkit';
import * as fs from 'fs';
import * as path from 'path';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BusinessProfile } from '../settings/entities/business-profile.entity';

@Injectable()
export class InvoiceService {
  constructor(
    @InjectRepository(BusinessProfile)
    private readonly profileRepo:
        Repository<BusinessProfile>,
  ) {}

  async generateInvoice(
    receivable: any,
    customer: any,
  ): Promise<string> {
    const profile =
        await this.profileRepo.findOne({
      where: {
        userId: receivable.userId,
      },
    });

    const fileName =
      `invoice-${Date.now()}.pdf`;

    const uploadPath = path.join(
      process.cwd(),
      'uploads',
      fileName,
    );

    const doc = new PDFDocument();

    const stream = fs.createWriteStream(
      uploadPath,
    );

    doc.pipe(stream);

    doc
        .fontSize(22)
        .text(
      profile?.businessName ??
          'CFCS Invoice',
      {
        align: 'center',
      },
    );

    doc.moveDown();

    doc
        .fontSize(14)
        .text(
      `Invoice #: INV-${Date.now()}`,
    );

    doc.moveDown();

    doc.text(
      `Owner: ${profile?.ownerName ?? 'N/A'}`,
    );

    doc.text(
      `Phone: ${profile?.phone ?? 'N/A'}`,
    );

    if (profile?.address != null) {
      doc.text(
        `Address: ${profile.address}`,
      );
    }

    if (profile?.gstNumber != null) {
      doc.text(
        `GST: ${profile.gstNumber}`,
      );
    }

    if (profile?.upiId != null) {
      doc.text(
        `UPI: ${profile.upiId}`,
      );
    }

    doc.moveDown();

    doc.text(
      `Customer: ${customer.name}`,
    );

    doc.text(
      `Customer Business: ${customer.businessName ?? 'N/A'}`,
    );

    doc.text(
      `Description: ${receivable.description}`,
    );

    doc.text(
      `Amount: ₹${receivable.totalAmount}`,
    );

    doc.text(
      `Due Date: ${receivable.dueDate}`,
    );

    doc.text(
      `Status: ${receivable.status}`,
    );

    doc.moveDown();

    doc.text(
      'Thank you for your business.',
      {
        align: 'center',
      },
    );

    doc.end();

    return new Promise((resolve) => {
      stream.on('finish', () => {
        resolve(fileName);
      });
    });
  }
}