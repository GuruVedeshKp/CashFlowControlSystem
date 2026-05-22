import { IsNotEmpty, Length, Matches } from 'class-validator';

export class LoginDto {
  @IsNotEmpty()
  @Matches(/^[0-9]{10,15}$/)
  phone!: string;

  @IsNotEmpty()
  @Length(8, 100)
  password!: string;
}