import { Component, OnInit } from '@angular/core';
import { ShortcutInput, ShortcutEventOutput } from 'ng-keyboard-shortcuts';
@Component({
    selector: 'ark-root',
    templateUrl: './app.component.html',
    styleUrls: ['./app.component.scss'],
})
export class AppComponent implements OnInit {
    shortcuts: ShortcutInput[] = [];
    title = 'ngTailBase';

    ngOnInit(): void {
        this.shortcuts.push({
            key: ['a r k enter'],
            label: 'Sequences Codes',
            description: 'ARK code!',
            command: (output: ShortcutEventOutput) => alert('Welcome Arijit'),
        });
    }
}
