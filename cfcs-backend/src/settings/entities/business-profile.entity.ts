import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('business_profiles')
export class BusinessProfile {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', unique: true })
  userId!: string;

  @Column({ name: 'business_name' })
  businessName!: string;

  @Column({ name: 'owner_name' })
  ownerName!: string;

  @Column()
  phone!: string;

  @Column({ nullable: true })
  address?: string;

  @Column({ name: 'gst_number', nullable: true })
  gstNumber?: string;

  @Column({ name: 'upi_id', nullable: true })
  upiId?: string;

  @Column({ nullable: true })
  logoPath?: string;

  @Column({
    default: 'polite',
  })
  defaultReminderTone!: string;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}