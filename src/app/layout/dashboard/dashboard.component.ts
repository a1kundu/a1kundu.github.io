// import { Component, OnInit, Inject, ViewChild, ElementRef } from '@angular/core';
import { HumanService } from '@S/human.service';
import { Component, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';
import { MatDrawer } from '@angular/material/sidenav';
import { Router } from '@angular/router';
import { KeyboardShortcutsHelpComponent, ShortcutInput } from 'ng-keyboard-shortcuts';

@Component({
    selector: 'app-dashboard',
    templateUrl: './dashboard.component.html',
    styleUrls: ['./dashboard.component.css'],
})
export class DashboardComponent implements OnInit {
    configForm = this.fb.group({
        name: []
    });
    @ViewChild(KeyboardShortcutsHelpComponent)
    public keyboardHelp!: KeyboardShortcutsHelpComponent;
    shortcuts: ShortcutInput[] = [];
    @ViewChild('drawer', { static: true })
    input!: MatDrawer;
    @ViewChild('drawer', { static: true })
    drawer!: MatDrawer;
    constructor(private router: Router, private fb: FormBuilder, private hS: HumanService) {
        // localStorage.setItem('sidebar_drawer', 'open');//ebantan NIC UAT dT 15.09.23.pdf  :: Issue 1
    }

    ngOnInit(): void {
        this.shortcuts.push(
            {
                key: ['cmd + b'],
                label: 'Hotkey',
                description: 'Toggle Sidebar',
                command: (e) => {
                    this.input.toggle();
                    this.togglePrevState();
                },
                preventDefault: true,
            },
            {
                key: ['cmd + shift + h'],
                label: 'Hotkey',
                description: 'Go To: Dashboard',
                command: (e) => {
                    this.router.navigate(['home']);
                },
                preventDefault: true,
            },
            {
                key: ['cmd + shift + e'],
                label: 'Hotkey',
                description: 'Go To: Budget Release',
                command: (e) => {
                    this.router.navigate(['wbBudgetEntry']);
                },
                preventDefault: true,
            },
            {
                key: ['cmd + shift + m'],
                label: 'Hotkey',
                description: 'Go To: Budget Release Modify',
                command: (e) => {
                    this.router.navigate(['wbBudgetModify']);
                },
                preventDefault: true,
            },
            {
                key: ['cmd + shift + a'],
                label: 'Hotkey',
                description: 'Go To: Budget Release Approve',
                command: (e) => {
                    this.router.navigate(['wbBudgetApprove']);
                },
                preventDefault: true,
            },
            {
                key: ['cmd + shift + s'],
                label: 'Hotkey',
                description: 'Go To: Sanction Letter Management Entry',
                command: (e) => {
                    this.router.navigate(['wbBudgetSanctionLetterMngmt']);
                },
                preventDefault: true,
            },
            {
                key: ['cmd + shift + d'],
                label: 'Hotkey',
                description: 'Toggle Dark Mode',
                command: (e) => {
                    this.toggleDarkMode();
                },
                preventDefault: true,
            }
        );
    }

    get prevSate(): boolean {
        return localStorage.getItem('sidebar_drawer') == 'open';
    }

    togglePrevState() {
        var openF: boolean = this.prevSate;
        localStorage.setItem('sidebar_drawer', !openF ? 'open' : 'close');
    }

    toggleDarkMode() {
        var darkThm: boolean = localStorage.getItem('th') == 'dark';
        document.body.classList.toggle('darkMode');
        localStorage.setItem('th', !darkThm ? 'dark' : 'normal');
    }

    logout() {}

    reload() {
        //ebantan NIC UAT dT 15.09.23.pdf  :: Issue 2
        location.reload();
    }

    nameChanged(){
        this.hS.data.name = this.configForm.value.name!;
    }
}
