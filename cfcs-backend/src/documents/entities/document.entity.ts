import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  DeleteDateColumn,
} from 'typeorm';
import { Receivable } from '../../receivables/entities/receivable.entity';

@Entity('documents')
export class Document {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'receivable_id' })
  receivableId!: string;

  @ManyToOne(() => Receivable, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'receivable_id' })
  receivable!: Receivable;

  // KEEP EXISTING
  @Column()
  fileName!: string;

  @Column()
  filePath!: string;

  @Column()
  mimeType!: string;

  // NEW PDF fields
  @Column({
    type: 'int',
    default: 0,
  })
  fileSize!: number;

  @Column({
    default: 'basic',
  })
  storageProvider!: string;

  @Column({
    nullable: true,
  })
  externalDocumentId?: string;

  @CreateDateColumn({ name: 'uploaded_at' })
  uploadedAt!: Date;

  @DeleteDateColumn({ name: 'deleted_at' })
  deletedAt?: Date;
}