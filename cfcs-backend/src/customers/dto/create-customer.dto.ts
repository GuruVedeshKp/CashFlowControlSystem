import { IsNotEmpty, IsOptional, IsString, Length, Matches } from 'class-validator';

export class CreateCustomerDto {
  @IsNotEmpty()
  @IsString()
  @Length(2, 100)
  name!: string;

  @IsNotEmpty()
  @Matches(/^[0-9]{10,15}$/, {
    message: 'Phone number must be between 10 and 15 digits',
  })
  phone!: string;

  @IsOptional()
  @IsString()
  @Length(0, 150)
  businessName?: string;
}