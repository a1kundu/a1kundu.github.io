'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import rehypeHighlight from 'rehype-highlight';
import { format } from 'date-fns';
import { Clock, Calendar, ArrowRight } from 'lucide-react';
import { BlogPost } from '../types/blog';
import { config } from '../config';

export default function Home() {
  const [posts, setPosts] = useState<BlogPost[]>([]);
  const [currentPosts, setCurrentPosts] = useState<BlogPost[]>([]);
  const [pageSize] = useState(5);
  const [pageIndex, setPageIndex] = useState(0);
  const [totalPosts, setTotalPosts] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadPosts();
  }, []);

  useEffect(() => {
    updateCurrentPosts();
  }, [posts, pageIndex, pageSize]);

  const loadPosts = async () => {
    try {
      const postsUrl = `https://raw.githubusercontent.com/${config.github.username}/${config.github.repo}/refs/heads/${config.github.branch}/src/assets/blogs/posts.json`;
      const response = await fetch(postsUrl);
      const posts: BlogPost[] = await response.json();

      // Filter out deleted posts and sort by date descending
      const filteredPosts = posts
        .filter(post => !post.deleted)
        .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

      // Load content for each post
      const contentPromises = filteredPosts.map(async (post) => {
        const contentUrl = `https://raw.githubusercontent.com/${config.github.username}/${config.github.repo}/refs/heads/${config.github.branch}/src/assets/blogs/${post.filename}`;
        const contentResponse = await fetch(contentUrl);
        const content = await contentResponse.text();
        return { ...post, content };
      });

      const postsWithContent = await Promise.all(contentPromises);
      setPosts(postsWithContent);
      setTotalPosts(postsWithContent.length);
    } catch (error) {
      console.error('Error loading posts:', error);
    } finally {
      setLoading(false);
    }
  };

  const updateCurrentPosts = () => {
    const startIndex = pageIndex * pageSize;
    setCurrentPosts(posts.slice(startIndex, startIndex + pageSize));
  };

  const getPostPreview = (content: string): string => {
    if (!content) return '';
    const lines = content.split('\n').filter(line => line.trim() !== '');
    const previewLines = lines.slice(0, 3);
    const preview = previewLines.join('\n');
    return preview.length > 200 ? preview.substring(0, 200) + '...' : preview + '...';
  };

  const getReadingTime = (content: string): string => {
    if (!content) return '1 min read';
    const wordsPerMinute = 200;
    const words = content.split(/\s+/).length;
    const minutes = Math.ceil(words / wordsPerMinute);
    return `${minutes} min read`;
  };

  const handlePageChange = (newPageIndex: number) => {
    setPageIndex(newPageIndex);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading posts...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto">
        {/* Hero Section */}
        <div className="text-center mb-16">
          <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-gray-900 mb-6">
            Hi, I&apos;m Arijit.
          </h1>
          <p className="text-xl text-gray-600 mb-8 max-w-2xl mx-auto">
            a passionate software developer<br />
            I create innovative solutions, share insights through my blog, and continuously learn to push the boundaries of what&apos;s possible.
          </p>
        </div>

        {/* Blog Posts Section */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold text-gray-900 text-center mb-8">Latest Blog Posts</h2>
          <div className="grid gap-8 md:grid-cols-1 lg:grid-cols-1">
            {currentPosts.map((post) => (
              <div key={post.filename} className="group bg-white rounded-xl shadow-lg hover:shadow-2xl transition-all duration-500 overflow-hidden border border-gray-100 hover:border-indigo-200 transform hover:-translate-y-1">
                {/* Card Header */}
                <div className="bg-gradient-to-r from-indigo-200 to-purple-200 px-6 py-4 border-b border-gray-200">
                  <div className="flex justify-between items-start">
                    <h3 className="text-xl font-bold text-gray-800 group-hover:text-indigo-900 transition-colors duration-300 leading-tight">
                      {post.title}
                    </h3>
                    <div className="flex items-center text-gray-600 text-sm ml-4 flex-shrink-0">
                      <Calendar className="mr-2 text-indigo-500" size={16} />
                      <span>{format(new Date(post.date), 'MMM dd, yyyy')}</span>
                    </div>
                  </div>
                </div>

                {/* Card Content */}
                <div className="p-6">
                  <div className="prose prose-sm max-w-none mb-6 text-gray-700 leading-relaxed">
                    <ReactMarkdown
                      remarkPlugins={[remarkGfm]}
                      rehypePlugins={[rehypeHighlight]}
                      components={{
                        p: ({ children }) => <p className="mb-4">{children}</p>,
                      }}
                    >
                      {getPostPreview(post.content || '')}
                    </ReactMarkdown>
                  </div>

                  {/* Read More Button */}
                  <div className="flex justify-between items-center">
                    <Link
                      href={`/blog/${post.filename}`}
                      className="inline-flex items-center px-2 py-1 bg-red-600 text-white font-medium rounded-lg hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-all duration-300 transform hover:scale-105 shadow-md hover:shadow-lg"
                    >
                      <span>Read Full Post</span>
                      <ArrowRight className="ml-2" size={16} />
                    </Link>

                    {/* Reading time estimate */}
                    <div className="text-sm text-gray-500 flex items-center">
                      <Clock className="mr-1 text-gray-400" size={16} />
                      <span>{getReadingTime(post.content || '')}</span>
                    </div>
                  </div>
                </div>

                {/* Subtle bottom accent */}
                <div className="h-1 bg-gradient-to-r from-indigo-400 to-purple-400 transform scale-x-0 group-hover:scale-x-100 transition-transform duration-500 origin-left"></div>
              </div>
            ))}
          </div>
        </div>

        {/* Pagination */}
        <div className="flex justify-center">
          <div className="flex items-center space-x-2">
            <button
              onClick={() => handlePageChange(pageIndex - 1)}
              disabled={pageIndex === 0}
              className="px-4 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Previous
            </button>
            <span className="text-sm text-gray-700">
              Page {pageIndex + 1} of {Math.ceil(totalPosts / pageSize)}
            </span>
            <button
              onClick={() => handlePageChange(pageIndex + 1)}
              disabled={pageIndex >= Math.ceil(totalPosts / pageSize) - 1}
              className="px-4 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Next
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
