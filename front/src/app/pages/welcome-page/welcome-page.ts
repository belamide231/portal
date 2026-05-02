import { Component, AfterViewInit, ElementRef, OnDestroy, ViewChild, ChangeDetectorRef } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';

import { ImageService } from '../../services/image-service';
import { ThemeService } from '../../services/theme-service-module';

@Component({
  selector: 'app-welcome-page',
  providers: [
    ImageService,
  ],
  imports: [
    CommonModule
  ],
  templateUrl: './welcome-page.html',
})
export class WelcomePage implements AfterViewInit, OnDestroy {
  private observer: IntersectionObserver | null = null;
  @ViewChild('displayElement') displayElement!: ElementRef;
  @ViewChild('intro') intro!: ElementRef;
  @ViewChild('heritage') heritage!: ElementRef;
  @ViewChild('programs') programs!: ElementRef;
  @ViewChild('contact') contact!: ElementRef;
  @ViewChild('portal') portal!: ElementRef;

  activeSection: string = 'intro';

  constructor(
    private el: ElementRef,
    public readonly image: ImageService,
    public readonly router: Router,
    public readonly theme: ThemeService,
    public readonly cdr: ChangeDetectorRef,
  ) {}

  ngAfterViewInit() {
    this.displayElement.nativeElement.addEventListener('scroll', () => {
      this.onScroll();
    });

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          
          this.observer?.unobserve(entry.target); 
        }
      });
    }, { threshold: 0.15 });

    const elements = this.el.nativeElement.querySelectorAll('.scroll-fade');
    elements.forEach((el: Element) => this.observer?.observe(el));
  }

  onScroll() {
    const scrollTop = this.displayElement.nativeElement.scrollTop;
    const introHeight = this.intro.nativeElement.offsetHeight;
    const heritageHeight = this.heritage.nativeElement.offsetHeight;
    const programsHeight = this.programs.nativeElement.offsetHeight;
    const portalHeight = this.portal.nativeElement.offsetHeight;
    
    if (scrollTop < introHeight) this.activeSection = 'intro';
    else if (scrollTop < introHeight + heritageHeight) this.activeSection = 'heritage';
    else if (scrollTop < introHeight + heritageHeight + programsHeight) this.activeSection = 'programs';
    else if (scrollTop < introHeight + heritageHeight + programsHeight + portalHeight) this.activeSection = 'contact';
    else if(scrollTop >= ((introHeight + heritageHeight + programsHeight + portalHeight) - 200)) this.activeSection = 'portal';
    
    this.cdr.detectChanges();
  }

  ngOnDestroy() {
    this.observer?.disconnect();
  }
}