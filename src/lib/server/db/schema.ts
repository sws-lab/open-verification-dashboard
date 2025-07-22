import { pgTable, serial, varchar, text, integer, date, unique, jsonb } from 'drizzle-orm/pg-core';

export const projects = pgTable('projects', {
	id: serial('id').primaryKey(),
	name: varchar('name', { length: 40 }).notNull().unique(),
	description: text('description').default(''),
	revision: integer('revision').notNull().default(0)
});

export const proofObligation = pgTable(
	'proof_obligation',
	{
		id: serial('id').primaryKey(),
		projectId: integer('project_id')
			.references(() => projects.id)
			.notNull(),
		projectRevision: integer('project_revision').notNull().default(0),
		name: varchar('name', { length: 40 }).notNull(),
		uploadDate: date('upload_date').notNull().defaultNow(),
		proofObligation: jsonb('proof_obligation').notNull(),
		safe: integer('safe').notNull(),
		warning: integer('warning').notNull(),
		error: integer('error').notNull()
	},
	(t) => [unique().on(t.name, t.projectId, t.projectRevision)]
);

export const conflict = pgTable('conflict', {
	id: serial('id').primaryKey(),
	projectId: integer('project_id')
		.references(() => projects.id)
		.notNull(),
	projectRevision: integer('revision').notNull().default(0),
	version: integer('version').notNull(),
	proofObligationId1: integer('proof_obligation_id_1')
		.references(() => proofObligation.id)
		.notNull(),
	proofObligationId2: integer('proof_obligation_id_2')
		.references(() => proofObligation.id)
		.notNull(),
	conflicts: jsonb('conflicts').notNull(),
	lastUpdated: date('last_updated').notNull().defaultNow()
});
