import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  CreateDateColumn,
  JoinColumn,
} from 'typeorm';
import { User } from '../../auth/entities/user.entity';
import { Receivable } from '../../receivables/entities/receivable.entity';

@Entity('payments')
export class Payment {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id' })
  userId!: string;

  @ManyToOne(() => User, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'receivable_id' })
  receivableId!: string;

  @ManyToOne(() => Receivable, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'receivable_id' })
  receivable!: Receivable;

  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
  })
  amount!: number;

  @Column({
    name: 'payment_date',
    type: 'timestamp',
  })
  paymentDate!: Date;

  @Column({
    type: 'text',
    nullable: true,
  })
  note?: string;

  @CreateDateColumn({
    name: 'created_at',
  })
  createdAt!: Date;
}