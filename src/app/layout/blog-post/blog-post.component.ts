import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { Title } from '@angular/platform-browser';
import { BlogPost } from '../../core/interfaces';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'ark-blog-post',
  templateUrl: './blog-post.component.html',
  styleUrls: ['./blog-post.component.scss']
})
export class BlogPostComponent implements OnInit {

  post: BlogPost | null = null;
  loading = true;

  constructor(private route: ActivatedRoute, private http: HttpClient, private titleService: Title) { }

  ngOnInit(): void {
    this.route.params.subscribe(params => {
      const filename = params['filename'];
      this.loadPost(filename);
    });
  }

  loadPost(filename: string): void {
    const postsUrl = `https://raw.githubusercontent.com/${environment.github.username}/${environment.github.repo}/refs/heads/${environment.github.branch}/src/assets/blogs/posts.json`;
    this.http.get<BlogPost[]>(postsUrl)
      .subscribe(posts => {
        const post = posts.find(p => p.filename === filename);
        if (post && !post.deleted) {
          this.post = post;
          this.titleService.setTitle(post.title);
          const contentUrl = `https://raw.githubusercontent.com/${environment.github.username}/${environment.github.repo}/refs/heads/${environment.github.branch}/src/assets/blogs/${filename}`;
          this.http.get(contentUrl, { responseType: 'text' })
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
