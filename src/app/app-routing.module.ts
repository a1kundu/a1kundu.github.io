import { ContactQrComponent } from '@L/contactQr/contactQr.component';
import { ResumeComponent } from './layout/resume/resume.component';
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { DashboardComponent } from '@L/dashboard/dashboard.component';
import { HomepageComponent } from './layout/homepage/homepage.component';

const routes: Routes = [
    {
        path: '',
        component: DashboardComponent,
        children: [
            { path: '', component: HomepageComponent },
            { path: 'resume', component: ResumeComponent }
        ],
    },
];

@NgModule({
    imports: [RouterModule.forRoot(routes, { useHash: true })],
    exports: [RouterModule],
})
export class AppRoutingModule {}
export const compDeclaration = [ResumeComponent, ContactQrComponent, DashboardComponent, HomepageComponent];
