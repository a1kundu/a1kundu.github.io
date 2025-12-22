import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { HttpClient } from '@angular/common/http';

interface BlogPost {
  title: string;
  date: string;
  filename: string;
  content?: string;
}

@Component({
  selector: 'ark-blog-post',
  templateUrl: './blog-post.component.html',
  styleUrls: ['./blog-post.component.scss']
})
export class BlogPostComponent implements OnInit {

  post: BlogPost | null = null;
  loading = true;

  constructor(private route: ActivatedRoute, private http: HttpClient) { }

  ngOnInit(): void {
    this.route.params.subscribe(params => {
      const filename = params['filename'];
      this.loadPost(filename);
    });
  }

  loadPost(filename: string): void {
    this.http.get<BlogPost[]>('assets/blogs/posts.json')
      .subscribe(posts => {
        const post = posts.find(p => p.filename === filename);
        if (post) {
          this.post = post;
          this.http.get(`assets/blogs/${filename}`, { responseType: 'text' })
            .subscribe(content => {
              this.post!.content = content;
              this.loading = false;
            });
        } else {
          this.loading = false;
        }
      });
  }

  getReadingTime(): number {
    if (!this.post?.content) return 0;
    // Average reading speed: 200 words per minute
    const wordsPerMinute = 200;
    const words = this.post.content.split(/\s+/).length;
    return Math.ceil(words / wordsPerMinute);
  }

}
