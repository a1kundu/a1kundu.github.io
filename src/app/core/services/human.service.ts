import { Human } from '$/interfaces';
import { Injectable } from '@angular/core';

@Injectable({
	providedIn: 'root',
})
export class HumanService {
	data: Human;
	constructor() {
		this.data = {
			name: 'Debasish Kundu',
			organization: 'Infosys Limited',
			designation: 'Senior System Engineer (Data Engineer) at Infosys',
			address: 'kolkata, West Bengal 700163',
			qr: 'BEGIN:VCARD\
            VERSION:3.0\
            N:DEBASISH KUNDU;\
            ORG:Infosys Limited\
            TITLE:Senior System Engineer\
            EMAIL;TYPE=INTERNET:dkundu532@gmail.com\
            TEL;TYPE=CELL:+919832850190\
            ADR:;;kolkata;West Bengal;700163;India\
            END:VCARD',
			summary: "Data Engineer with 4 years of experience in designing, developing, and optimizing scalable data pipelines and ETL workflows. Strong expertise in PySpark, Python, Azure Data Factory (ADF), Databricks, and data migration across environments. Proven ability to automate data workflows, implement monitoring solutions, and optimize data distribution for high-performance analytics. Adept at working in fast-paced environments and collaborating across teams to deliver reliable data solutions. Recognized with the INSTA Award for three consecutive quarters for exceptional performance and delivery.",
			email: {
				text: 'dkundu532@gmail.com',
				hyperLink: 'mailto:dkundu532@gmail.com',
			},
			linkedin: {
				text: '/in/debasish-kundu',
				hyperLink: 'https://www.linkedin.com/in/dk-86205b193',
			},
			phone: {
				text: '9832850190',
				hyperLink: 'tel:+919832850190',
			},
			github: {
				text: '',
				hyperLink: '',
			},
			leetcode: {
				text: '',
				hyperLink: '',
			},
			hackerrank: {
				text: '',
				hyperLink: '',
			},
			experience: [
				{
					heading: 'Senior System Engineer at Infosys Limited',
					duration: 'March 2025 - Present',
					projects: [
						{
							title: 'E-commerce Data Pipeline (End-to-End ETL System)',
							description: 'Designed and implemented a scalable data pipeline for processing sales, customer, and product data.',
							responsibility: [
								'Multi-source data (sales, customer, product) was scattered with no centralized store — ingested into Azure Data Lake via ADF pipelines, enabling unified analytics access.',
								'Raw data was unprocessed and not analytics-ready — transformed and enriched at scale using PySpark in Databricks, producing curated Gold-layer datasets for downstream consumption.',
								'Pipeline performance was suboptimal — tuned Spark jobs through partitioning, caching, and broadcast join optimizations, improving throughput by 25%.',
								'Earned the INSTA Award for three consecutive quarters (2025–2026) for outstanding performance, process improvements, and consistent delivery of project milestones.',
							],
							techstack: ['Azure Data Factory', 'Azure Databricks', 'PySpark', 'Delta Lake', 'Azure Data Lake Storage'],
							liveLinks: [],
							modules: [],
						},
					],
				},
				{
					heading: 'System Engineer at Infosys Limited',
					duration: 'April 2023 - March 2025',
					projects: [
						{
							title: 'Data Engineering & Pipeline Development',
							description: '',
							responsibility: [
								'Ad-hoc scripts caused inconsistent ingestion — built scalable PySpark pipelines for reliable processing of heterogeneous structured and unstructured data.',
								'Manual orchestration was error-prone — automated end-to-end data flow by developing ADF pipelines with triggers, datasets, and monitoring.',
								'On-premise data silos limited scalability — migrated to Azure Cloud enabling cost-efficient and scalable processing.',
								'Inconsistent transformations caused quality issues — standardized ETL logic in Databricks notebooks with validation; documented workflows for maintainability.',
							],
							techstack: ['PySpark', 'Azure Data Factory', 'Databricks', 'Azure Cloud'],
							liveLinks: [],
							modules: [],
						},
						{
							title: 'Enterprise Azure Lakehouse Platform',
							description: 'Built Bronze/Silver/Gold architecture.',
							responsibility: [
								'No data tiering caused quality and compliance gaps — architected Bronze/Silver/Gold Lakehouse on ADLS with Delta Lake ensuring ACID compliance and schema evolution.',
								'Spark jobs had performance bottlenecks — resolved via Z-ordering, liquid clustering, and partition tuning, improving workload efficiency by 25%.',
							],
							techstack: ['Azure Data Factory', 'Azure Databricks', 'PySpark', 'Delta Lake', 'Azure Data Lake Storage', 'Azure SQL'],
							liveLinks: [],
							modules: [],
						},
						{
							title: 'Enterprise Knowledge Ingestion & Search Pipeline',
							description: '(Personal Project) - Built an end-to-end data pipeline to ingest, process, and index enterprise documents for semantic search and RAG-based retrieval.',
							responsibility: [
								'Enterprise documents were unindexed and unsearchable — built a Databricks pipeline to extract, chunk, and transform unstructured data at scale.',
								'Keyword search was insufficient for knowledge retrieval — generated embeddings via Azure OpenAI and loaded vector representations into Azure AI Search for semantic similarity.',
								'ML runs lacked reproducibility — tracked and versioned embedding models and pipeline runs using MLflow.',
								'Manual deployments caused inconsistent releases — automated CI/CD using Azure DevOps for reliable scheduling and deployment of the full pipeline.',
								'Simple search returned irrelevant answers — integrated LangChain to orchestrate RAG on indexed data, enabling contextual enterprise knowledge retrieval.',
							],
							techstack: ['Azure OpenAI', 'Azure AI Search', 'LangChain', 'Databricks', 'MLflow', 'Azure DevOps'],
							liveLinks: [],
							modules: [],
						},
					],
				},
				{
					heading: 'System Engineer Trainee at Infosys Limited, Mysore',
					duration: 'October 2022 - March 2023',
					projects: [
						{
							title: 'Foundational Training',
							description: 'Trained in Azure Cloud, Python, SQL, and data engineering fundamentals.',
							responsibility: [
								'Lacked hands-on cloud & data skills — built foundational expertise in Azure Cloud, Python, SQL, and ETL workflows, enabling immediate contribution to production-grade data pipelines.',
							],
							techstack: ['Azure Cloud', 'Python', 'SQL'],
							liveLinks: [],
							modules: [],
						},
					],
				},
			],
			skills: [
				{
					title: 'Data Engineering',
					skills: [
						{ title: 'Python', rating: 0.9 },
						{ title: 'PySpark', rating: 0.9 },
						{ title: 'SQL', rating: 0.9 },
						{ title: 'Advanced SQL', rating: 0.9 },
						{ title: 'ETL/ELT', rating: 0.9 },
						{ title: 'Data Migration', rating: 0.9 },
						{ title: 'Data Distribution', rating: 0.9 },
					],
				},
				{
					title: 'Azure / Cloud',
					skills: [
						{ title: 'Azure Data Factory', rating: 0.9 },
						{ title: 'Azure Databricks', rating: 0.9 },
						{ title: 'Delta Lake', rating: 0.9 },
						{ title: 'Azure Data Lake Storage', rating: 0.9 },
						{ title: 'Azure SQL', rating: 0.9 },
						{ title: 'Azure Storage', rating: 0.9 },
						{ title: 'Azure OpenAI', rating: 0.8 },
						{ title: 'Azure AI Search', rating: 0.8 },
						{ title: 'Azure DevOps', rating: 0.8 },
					],
				},
				{
					title: 'Monitoring',
					skills: [
						{ title: 'ADF Monitoring', rating: 0.9 },
						{ title: 'Databricks Job Monitoring', rating: 0.9 },
					],
				},
				{
					title: 'Source Control',
					skills: [
						{ title: 'GIT', rating: 0.9 },
						{ title: 'GitHub', rating: 0.9 },
					],
				},
				{
					title: 'AI / ML',
					skills: [
						{ title: 'LangChain', rating: 0.8 },
						{ title: 'MLflow', rating: 0.8 },
					],
				},
				{
					title: 'Performance & Quality',
					skills: [
						{ title: 'Performance Optimization', rating: 0.9 },
						{ title: 'Debugging', rating: 0.9 },
						{ title: 'Documentation', rating: 0.9 },
					],
				},
				{
					title: 'Soft Skills',
					skills: [
						{ title: 'Problem-Solving', rating: 1 },
						{ title: 'Critical Thinking', rating: 1 },
						{ title: 'Communication', rating: 1 },
						{ title: 'Teamwork', rating: 1 },
					],
				},
				{
					title: 'Certifications',
					skills: [
						{ title: 'AZ-900 Azure Fundamentals', rating: 1 },
						{ title: 'AWS Certified Cloud Practitioner', rating: 1 },
						{ title: 'Infosys Certified Python Associate', rating: 1 },
						{ title: 'Infosys Certified Python Programmer', rating: 1 },
						{ title: 'Infosys Certified Database and SQL Professional', rating: 1 },
					],
				},
			],
		};
	}
}
