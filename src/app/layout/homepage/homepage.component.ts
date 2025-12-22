import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { PageEvent } from '@angular/material/paginator';

interface BlogPost {
  title: string;
  date: string;
  filename: string;
  content?: string;
}

@Component({
  selector: 'ark-homepage',
  templateUrl: './homepage.component.html',
  styleUrls: ['./homepage.component.scss']
})
export class HomepageComponent implements OnInit {

  posts: BlogPost[] = [];
  currentPosts: BlogPost[] = [];
  pageSize = 2;
  pageIndex = 0;
  totalPosts = 0;

  constructor(private http: HttpClient) { }

  ngOnInit(): void {
    this.loadPosts();
  }

  loadPosts(): void {
    this.http.get<BlogPost[]>('assets/blogs/posts.json')
      .subscribe(posts => {
        // Sort by date descending (latest first)
        this.posts = posts.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
        this.totalPosts = this.posts.length;
        this.updateCurrentPosts();
        this.loadPostContents();
      });
  }

  updateCurrentPosts(): void {
    const startIndex = this.pageIndex * this.pageSize;
    this.currentPosts = this.posts.slice(startIndex, startIndex + this.pageSize);
  }

  loadPostContents(): void {
    this.posts.forEach(post => {
      this.http.get(`assets/blogs/${post.filename}`, { responseType: 'text' })
        .subscribe(content => {
          post.content = content;
        });
    });
  }

  onPageChange(event: PageEvent): void {
    this.pageIndex = event.pageIndex;
    this.pageSize = event.pageSize;
    this.updateCurrentPosts();
  }

}
