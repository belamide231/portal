import { ChangeDetectorRef, Component } from '@angular/core';
import { ImageService } from '../../services/image-service';
import { ApiServiceModule } from '../../services/api-service-module';

@Component({
  selector: 'app-dashboard-page',
  imports: [],
  providers: [
    ImageService,
    ApiServiceModule
  ],
  templateUrl: './dashboard-page.html',
})
export class DashboardPage {
  constructor(
    public readonly image: ImageService,
    private readonly api: ApiServiceModule,
    private readonly cdr: ChangeDetectorRef
  ) {}
}
