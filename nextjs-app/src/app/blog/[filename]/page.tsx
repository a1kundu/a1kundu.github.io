import { Metadata } from 'next';
import Link from 'next/link';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import rehypeHighlight from 'rehype-highlight';
import { format } from 'date-fns';
import { ArrowLeft, Calendar, Clock, User, Linkedin, Github } from 'lucide-react';
import { BlogPost } from '../../../types/blog';
import { config } from '../../../config';

export async function generateStaticParams() {
  try {
    const postsUrl = `https://raw.githubusercontent.com/${config.github.username}/${config.github.repo}/refs/heads/${config.github.branch}/src/assets/blogs/posts.json`;
    const response = await fetch(postsUrl);
    const posts: BlogPost[] = await response.json();

    return posts
      .filter(post => !post.deleted)
      .map((post) => ({
        filename: post.filename,
      }));
  } catch (error) {
    console.error('Error generating static params:', error);
    return [];
  }
}

export async function generateMetadata({ params }: { params: Promise<{ filename: string }> }): Promise<Metadata> {
  try {
    const { filename } = await params;
    const postsUrl = `https://raw.githubusercontent.com/${config.github.username}/${config.github.repo}/refs/heads/${config.github.branch}/src/assets/blogs/posts.json`;
    const response = await fetch(postsUrl);
    const posts: BlogPost[] = await response.json();

    const post = posts.find(p => p.filename === filename);
    if (post && !post.deleted) {
      return {
        title: post.title,
      };
    }
  } catch (error) {
    console.error('Error generating metadata:', error);
  }

  return {
    title: 'Blog Post',
  };
}

async function getPost(filename: string): Promise<BlogPost | null> {
  try {
    const postsUrl = `https://raw.githubusercontent.com/${config.github.username}/${config.github.repo}/refs/heads/${config.github.branch}/src/assets/blogs/posts.json`;
    const response = await fetch(postsUrl);
    const posts: BlogPost[] = await response.json();

    const foundPost = posts.find(p => p.filename === filename);
    if (foundPost && !foundPost.deleted) {
      const contentUrl = `https://raw.githubusercontent.com/${config.github.username}/${config.github.repo}/refs/heads/${config.github.branch}/src/assets/blogs/${filename}`;
      const contentResponse = await fetch(contentUrl);
      const content = await contentResponse.text();
      return { ...foundPost, content };
    }
  } catch (error) {
    console.error('Error loading post:', error);
  }
  return null;
}

export default async function BlogPostPage({ params }: { params: Promise<{ filename: string }> }) {
  const { filename } = await params;
  const post = await getPost(filename);

  if (!post) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto text-center py-20">
          <div className="text-6xl text-gray-300 mb-4">
            📄
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Post Not Found</h2>
          <p className="text-gray-600 mb-6">The blog post you're looking for doesn't exist.</p>
          <Link
            href="/"
            className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors duration-200"
          >
            <ArrowLeft className="mr-2 -ml-1" size={16} />
            Go Home
          </Link>
        </div>
      </div>
    );
  }

  const getReadingTime = (): number => {
    if (!post.content) return 0;
    const wordsPerMinute = 200;
    const words = post.content.split(/\s+/).length;
    return Math.ceil(words / wordsPerMinute);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        <div className="bg-white rounded-xl shadow-lg overflow-hidden">
          {/* Header Section */}
          <div className="bg-gradient-to-r from-indigo-600 to-purple-600 px-8 py-12 text-white">
            <div className="mb-6">
              <Link
                href="/"
                className="inline-flex items-center px-4 py-2 border border-white/20 text-sm font-medium rounded-lg text-white bg-white/10 hover:bg-white/20 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-white/50 transition-all duration-200 backdrop-blur-sm"
              >
                <ArrowLeft className="mr-2 -ml-1" size={16} />
                Back to Home
              </Link>
            </div>

            {/* Title Section */}
            <div className="space-y-4">
              <div className="flex items-center space-x-2 text-indigo-100">
                <Calendar size={16} />
                <span className="text-sm font-medium">{format(new Date(post.date), 'MMM dd, yyyy')}</span>
                <span className="text-indigo-200">•</span>
                <span className="text-sm">{getReadingTime()} min read</span>
              </div>

              <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold leading-tight text-white">
                {post.title}
              </h1>

              <div className="w-16 h-1 bg-white/30 rounded-full"></div>
            </div>
          </div>

          {/* Content Section */}
          <div className="px-8 py-12">
            <div className="prose prose-lg prose-indigo max-w-none">
              <ReactMarkdown
                remarkPlugins={[remarkGfm]}
                rehypePlugins={[rehypeHighlight]}
                components={{
                  h1: ({ children }) => <h1 className="text-3xl font-bold text-gray-900 mb-4">{children}</h1>,
                  h2: ({ children }) => <h2 className="text-2xl font-bold text-gray-900 mb-3 border-b border-gray-200 pb-2">{children}</h2>,
                  h3: ({ children }) => <h3 className="text-xl font-semibold text-gray-900 mb-2">{children}</h3>,
                  p: ({ children }) => <p className="mb-4 text-gray-700 leading-relaxed">{children}</p>,
                  ul: ({ children }) => <ul className="mb-4 pl-6 list-disc text-gray-700">{children}</ul>,
                  ol: ({ children }) => <ol className="mb-4 pl-6 list-decimal text-gray-700">{children}</ol>,
                  li: ({ children }) => <li className="mb-2">{children}</li>,
                  blockquote: ({ children }) => (
                    <blockquote className="border-l-4 border-indigo-500 pl-4 py-2 my-4 bg-gray-50 italic text-gray-600">
                      {children}
                    </blockquote>
                  ),
                  a: ({ children, href }) => (
                    <a href={href} className="text-indigo-600 hover:text-indigo-800 underline">
                      {children}
                    </a>
                  ),
                  code: ({ children, className }) => {
                    const isInline = !className;
                    return isInline ? (
                      <code className="bg-gray-100 px-1 py-0.5 rounded text-sm font-mono">
                        {children}
                      </code>
                    ) : (
                      <code className={className}>{children}</code>
                    );
                  },
                  pre: ({ children }) => (
                    <pre className="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto my-4">
                      {children}
                    </pre>
                  ),
                  table: ({ children }) => (
                    <table className="min-w-full divide-y divide-gray-200 my-4">
                      {children}
                    </table>
                  ),
                  th: ({ children }) => (
                    <th className="px-6 py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {children}
                    </th>
                  ),
                  td: ({ children }) => (
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {children}
                    </td>
                  ),
                }}
              >
                {post.content}
              </ReactMarkdown>
            </div>

            {/* Footer */}
            <div className="mt-16 pt-8 border-t border-gray-200">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-4">
                  <div className="w-10 h-10 bg-gradient-to-r from-indigo-500 to-purple-500 rounded-full flex items-center justify-center">
                    <User className="text-white" size={20} />
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">Arijit Kundu</p>
                    <p className="text-sm text-gray-500">Software Developer & Tech Enthusiast</p>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <a
                    href="https://www.linkedin.com/in/a1kundu"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="p-2 text-gray-400 hover:text-indigo-600 transition-colors duration-200"
                  >
                    <Linkedin size={20} />
                  </a>
                  <a
                    href="https://github.com/a1kundu"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="p-2 text-gray-400 hover:text-indigo-600 transition-colors duration-200"
                  >
                    <Github size={20} />
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
