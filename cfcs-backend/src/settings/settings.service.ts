import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BusinessProfile } from './entities/business-profile.entity';
import { SaveBusinessProfileDto } from './dto/save-business-profile.dto';

@Injectable()
export class SettingsService {
  constructor(
    @InjectRepository(BusinessProfile)
    private readonly profileRepo:
        Repository<BusinessProfile>,
  ) {}

  async saveProfile(
    userId: string,
    dto: SaveBusinessProfileDto,
  ) {
    let profile =
        await this.profileRepo.findOne({
      where: { userId },
    });

    if (!profile) {
      profile =
          this.profileRepo.create({
        userId,
        ...dto,
      });
    } else {
      Object.assign(profile, dto);
    }

    await this.profileRepo.save(profile);

    return {
      success: true,
      data: profile,
    };
  }

  async getProfile(userId: string) {
    const profile =
        await this.profileRepo.findOne({
      where: { userId },
    });

    return {
      success: true,
      data: profile,
    };
  }
}