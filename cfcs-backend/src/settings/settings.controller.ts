import {
  Controller,
  Post,
  Get,
  Body,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SettingsService } from './settings.service';
import { SaveBusinessProfileDto } from './dto/save-business-profile.dto';

@Controller('api/v1/settings')
@UseGuards(JwtAuthGuard)
export class SettingsController {
  constructor(
    private readonly settingsService:
        SettingsService,
  ) {}

  @Post('business-profile')
  saveProfile(
    @Req() req,
    @Body() dto: SaveBusinessProfileDto,
  ) {
    return this.settingsService.saveProfile(
      req.user.userId,
      dto,
    );
  }

  @Get('business-profile')
  getProfile(@Req() req) {
    return this.settingsService.getProfile(
      req.user.userId,
    );
  }
}