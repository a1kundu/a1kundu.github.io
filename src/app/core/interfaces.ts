export interface Module {
    name: string;
    description: string;
    responsibility: string[] | string;
    challenges: string[] | string;
    contributions: string[] | string;
    techstack: string[];
}
export interface Project {
    title: string;
    liveLinks: string[];
    description: string; //additional
    responsibility: string[] | string;
    techstack: string[];
    modules: Module[];
}
export interface SkillArea {
    title: string;
    skills: Skill[];
}
export interface Skill {
    title: string;
    rating: number;
}
export interface Link {
    text: string;
    hyperLink: string;
}
export interface Section {
    heading: string;
    duration: string;
    projects: Project[];
}
export interface Human {
    name: string;
    organization: string;
    designation: string;
    address: string;
    summary: string;
    email: Link;
    phone: Link;
    linkedin: Link;
    github: Link;
    leetcode: Link;
    hackerrank: Link;
    qr: string;
    experience: Section[];
    skills: SkillArea[];
}
