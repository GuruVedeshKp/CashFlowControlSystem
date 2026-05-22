import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  DeleteDateColumn,
  JoinColumn,
} from 'typeorm';
import { User } from '../../auth/entities/user.entity';
import { Customer } from '../../customers/entities/customer.entity';
import { ReceivableStatus } from '../enums/receivable-status.enum';
import { OneToMany } from 'typeorm';
import { Document } from '../../documents/entities/document.entity';

@Entity('receivables')
export class Receivable {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'customer_id' })
  customerId!: string;

  @ManyToOne(() => Customer, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'customer_id' })
  customer!: Customer;

  @Column({ type: 'text' })
  description!: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  totalAmount!: number;

  @Column({
    name: 'amount_paid',
    type: 'decimal',
    precision: 10,
    scale: 2,
    default: 0,
  })
  amountPaid!: number;

  @Column({
    name: 'balance_amount',
    type: 'decimal',
    precision: 10,
    scale: 2,
  })
  balanceAmount!: number;

  @Column({ name: 'due_date', type: 'date' })
  dueDate!: Date;

  @Column({
    type: 'enum',
    enum: ReceivableStatus,
    default: ReceivableStatus.PENDING,
  })
  status!: ReceivableStatus;

  @Column({ name: 'paid_at', type: 'timestamp', nullable: true })
  paidAt?: Date;

  @Column({ type: 'boolean', default: false })
  isArchived!: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;

  @DeleteDateColumn({ name: 'deleted_at' })
  deletedAt?: Date;

  @Column({ nullable: true })
  lastReminderDate!: Date;

  @Column({ default: 0 })
  reminderCount!: number;

  @Column({
    type: 'text',
    nullable: true,
  })
  paidNote?: string;

  @Column({ nullable: true })
  paidDate!: Date;

  @OneToMany(() => Document, (document) => document.receivable)
  documents!: Document[];
}