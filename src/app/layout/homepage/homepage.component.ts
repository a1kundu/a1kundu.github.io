import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { PageEvent } from '@angular/material/paginator';
import { forkJoin } from 'rxjs';
import { BlogPost } from '../../core/interfaces';

@Component({
  selector: 'ark-homepage',
  templateUrl: './homepage.component.html',
  styleUrls: ['./homepage.component.scss']
})
export class HomepageComponent implements OnInit {

  posts: BlogPost[] = [];
  currentPosts: BlogPost[] = [];
  pageSize = 5;
  pageIndex = 0;
  totalPosts = 0;

  constructor(private http: HttpClient) { }

  ngOnInit(): void {
    this.loadPosts();
  }

  loadPosts(): void {
    this.http.get<BlogPost[]>('assets/blogs/posts.json')
      .subscribe(posts => {
        // Filter out deleted posts and sort by date descending (latest first)
        this.posts = posts.filter(post => !post.deleted).sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

        // Load content for each post
        const contentRequests = this.posts.map(post =>
          this.http.get(`assets/blogs/${post.filename}`, { responseType: 'text' })
        );

        forkJoin(contentRequests).subscribe(contents => {
          this.posts.forEach((post, index) => {
            post.content = contents[index];
          });
          this.totalPosts = this.posts.length;
          this.updateCurrentPosts();
        });
      });
  }

  updateCurrentPosts(): void {
    const startIndex = this.pageIndex * this.pageSize;
    this.currentPosts = this.posts.slice(startIndex, startIndex + this.pageSize);
  }

  onPageChange(event: PageEvent): void {
    this.pageIndex = event.pageIndex;
    this.pageSize = event.pageSize;
    this.updateCurrentPosts();
  }

  getPostPreview(content: string): string {
    if (!content) return '';
    const lines = content.split('\n').filter(line => line.trim() !== '');
    const previewLines = lines.slice(0, 3);
    const preview = previewLines.join('\n');
    return preview.length > 200 ? preview.substring(0, 200) + '...' : preview + '...';
  }

  getReadingTime(content: string): string {
    if (!content) return '1 min read';
    const wordsPerMinute = 200;
    const words = content.split(/\s+/).length;
    const minutes = Math.ceil(words / wordsPerMinute);
    return `${minutes} min read`;
  }

}
