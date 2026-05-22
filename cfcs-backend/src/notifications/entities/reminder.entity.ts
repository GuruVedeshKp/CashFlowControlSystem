import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  JoinColumn,
} from 'typeorm';
import { User } from '../../auth/entities/user.entity';
import { Receivable } from '../../receivables/entities/receivable.entity';

@Entity('reminders')
export class Reminder {
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
    type: 'enum',
    enum: ['polite', 'firm'],
  })
  tone!: 'polite' | 'firm';

  @Column({
    name: 'sent_at',
    type: 'timestamp',
    nullable: true,
  })
  sentAt?: Date;

  @CreateDateColumn({
    name: 'created_at',
  })
  createdAt!: Date;
}