import {
  IsString,
  IsOptional,
} from 'class-validator';

export class SaveBusinessProfileDto {
  @IsString()
  businessName!: string;

  @IsString()
  ownerName!: string;

  @IsString()
  phone!: string;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsString()
  gstNumber?: string;

  @IsOptional()
  @IsString()
  upiId?: string;

  @IsOptional()
  @IsString()
  defaultReminderTone?: string;
}