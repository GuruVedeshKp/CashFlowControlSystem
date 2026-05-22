import {
  IsUUID,
  IsNumber,
  Min,
  IsDateString,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class CreatePaymentDto {
  @IsUUID()
  receivableId!: string;

  @IsNumber()
  @Min(0.01)
  amount!: number;

  @IsDateString()
  paymentDate!: string;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;
}