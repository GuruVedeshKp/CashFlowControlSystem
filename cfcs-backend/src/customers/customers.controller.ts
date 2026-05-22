import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
  Req,
} from '@nestjs/common';
import { CustomersService } from './customers.service';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { UpdateCustomerDto } from './dto/update-customer.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('api/v1/customers')
@UseGuards(JwtAuthGuard)
export class CustomersController {
  constructor(private readonly customersService: CustomersService) {}

  @Post()
  create(@Req() req, @Body() dto: CreateCustomerDto) {
    return this.customersService.create(req.user.userId, dto);
  }

  @Get()
  findAll(@Req() req) {
    return this.customersService.findAll(req.user.userId);
  }

  @Get(':id/history')
  getHistory(
    @Req() req,
    @Param('id') id: string,
  ) {
    return this.customersService.getCustomerHistory(
      req.user.userId,
      id,
    );
  }

  @Get(':id')
  findOne(@Req() req, @Param('id') id: string) {
    return this.customersService.findOne(req.user.userId, id);
  }

  @Patch(':id')
  update(
    @Req() req,
    @Param('id') id: string,
    @Body() dto: UpdateCustomerDto,
  ) {
    return this.customersService.update(req.user.userId, id, dto);
  }

  @Delete(':id')
  remove(@Req() req, @Param('id') id: string) {
    return this.customersService.remove(req.user.userId, id);
  }
}