import { IsUUID, IsString, IsNotEmpty, IsNumber, Min, IsDateString } from 'class-validator';

export class CreateReceivableDto {
  @IsUUID()
  customerId!: string;

  @IsString()
  @IsNotEmpty()
  description!: string;

  @IsNumber()
  @Min(0)
  totalAmount!: number;

  @IsDateString()
  dueDate!: Date;
}