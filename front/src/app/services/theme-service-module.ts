import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ThemeService {
  private themeSubject = new BehaviorSubject<'1' | '0'>('0');

  public isDarkMode$: Observable<'1' | '0'> = this.themeSubject.asObservable();

  constructor() {
    const savedTheme = localStorage.getItem("isDarkMode");
    if (savedTheme === '1' || savedTheme === '0') {
      this.themeSubject.next(savedTheme);
    }
  }

  public switchTheme(): void {
    const nextValue = this.themeSubject.value === "1" ? "0" : "1";
    this.themeSubject.next(nextValue);
    localStorage.setItem("isDarkMode", nextValue);
  }
}