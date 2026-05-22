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
  Query,
} from '@nestjs/common';
import { ReceivablesService } from './receivables.service';
import { CreateReceivableDto } from './dto/create-receivable.dto';
import { UpdateReceivableDto } from './dto/update-receivable.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UpdateDueDateDto } from './dto/update-due-date.dto';
import { SendReminderDto } from './dto/send-reminder.dto';
import { MarkPaidDto } from './dto/mark-paid.dto';

@Controller('api/v1/receivables')
@UseGuards(JwtAuthGuard)
export class ReceivablesController {
  constructor(private readonly receivablesService: ReceivablesService) {}

  @Post()
  create(@Req() req, @Body() dto: CreateReceivableDto) {
    return this.receivablesService.create(req.user.userId, dto);
  }

  @Get()
  findAll(@Req() req, @Query('customerId') customerId?: string) {
    return this.receivablesService.findAll(req.user.userId, customerId);
  }

  @Get('follow-up')
  getFollowUp(@Req() req) {
    return this.receivablesService.getFollowUp(req.user.userId);
  }

  @Get('history')
  findHistory(@Req() req) {
    return this.receivablesService.findHistory(req.user.userId);
  }

  @Get(':id')
  findOne(@Req() req, @Param('id') id: string) {
    return this.receivablesService.findOne(req.user.userId, id);
  }

  @Patch(':id')
  update(
    @Req() req,
    @Param('id') id: string,
    @Body() dto: UpdateReceivableDto,
  ) {
    return this.receivablesService.update(req.user.userId, id, dto);
  }

  @Patch(':id/due-date')
  updateDueDate(
    @Param('id') id: string,
    @Body() dto: UpdateDueDateDto,
    @Req() req,
  ) {
    return this.receivablesService.updateDueDate(id, req.user.userId, dto);
  }

  @Patch(':id/restore')
  restore(@Param('id') id: string, @Req() req) {
    return this.receivablesService.restore(id, req.user.userId);
  }

  @Delete(':id')
  remove(@Req() req, @Param('id') id: string) {
    return this.receivablesService.remove(req.user.userId, id);
  }

  @Post(':id/send-reminder')
  sendReminder(
    @Param('id') id: string,
    @Body() dto: SendReminderDto,
    @Req() req,
  ) {
    return this.receivablesService.sendReminder(id, req.user.userId, dto);
  }

  @Post(':id/mark-paid')
  markPaid(@Param('id') id: string, @Body() dto: MarkPaidDto, @Req() req) {
    return this.receivablesService.markPaid(id, req.user.userId, dto);
  }
}
