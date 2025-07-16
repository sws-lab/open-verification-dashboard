import { pgTable, serial, varchar, text, integer, json, date } from 'drizzle-orm/pg-core';

export const projects = pgTable('projects', {
	id: serial('id').primaryKey(),
	name: varchar('name', { length: 100 }).notNull().unique(),
	description: text('description').default(''),
	revision: integer('revision').notNull().default(0)
});

export const analyzer = pgTable('analyzer', {
	id: serial('id').primaryKey(),
	name: varchar('name', { length: 100 }).notNull().unique(),
});

export const proofObligation = pgTable('proof_obligation', {
	id: serial('id').primaryKey(),
	projectId: integer('project_id').references(() => projects.id).notNull(),
	projectRevision: integer('project_revision').notNull().default(0),
	analyzerId: integer('analyzer_id').references(() => analyzer.id).notNull(),
	revision: integer('revision').notNull().default(0),
	lastUpdated: date('last_updated').notNull().defaultNow(),
	proofObligation: json('proof_obligation').notNull(),
});

export const conflict = pgTable('conflict', {
	id: serial('id').primaryKey(),
	projectId: integer('project_id').references(() => projects.id).notNull(),
	projectRevision: integer('revision').notNull().default(0),
	proofObligationId1: integer('proof_obligation_id_1').references(() => proofObligation.id).notNull(),
	proofObligationId2: integer('proof_obligation_id_2').references(() => proofObligation.id).notNull(),
	conflicts: json('conflicts').notNull(),
	lastUpdated: date('last_updated').notNull().defaultNow(),
});

