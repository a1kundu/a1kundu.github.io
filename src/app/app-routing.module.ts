import { ContactQrComponent } from '@L/contactQr/contactQr.component';
import { ResumeComponent } from './layout/resume/resume.component';
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { HomepageComponent } from './layout/homepage/homepage.component';
import { BlogPostComponent } from './layout/blog-post/blog-post.component';

const routes: Routes = [
    { path: '', component: HomepageComponent },
    { path: 'resume', component: ResumeComponent },
    { path: 'blog/:filename', component: BlogPostComponent },
];

@NgModule({
    imports: [RouterModule.forRoot(routes, { useHash: true })],
    exports: [RouterModule],
})
export class AppRoutingModule {}
export const compDeclaration = [ResumeComponent, ContactQrComponent, HomepageComponent, BlogPostComponent];
