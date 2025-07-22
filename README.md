# Dashboard UI

This is a SvelteKit project that provides an ui to the dashboard.

## Initializing the project

The project uses postgres as a database, so you need to have a PostgreSQL server running and configured.

To initialize the project, you first need to add a .env file with the following variables:

```env
DATABASE_URL="postgres://user:password@url:port/database_name"
DASHBOARD_APP_PATH="whatever/path/to/dashboard/executable"
PUBLIC_PAGE_SIZE=30
VERSION=0
```

Then, run the following commands to settup the database and install dependencies:

```bash
npm install
npx drizzle-kit generate
npx drizzle-kit push
npm run prepare
```

## What to do if the dashboad executable changes?

If the dashboard executable changes, you need to update the `VERSION` variable in the `.env` file. This will regenerate the database entries when requested by the ui.

## Developing

Once you've created a project and installed dependencies with `npm install` (or `pnpm install` or `yarn`), start a development server:

```bash
npm run dev

# or start the server and open the app in a new browser tab
npm run dev -- --open
```

## Building

To create a production version of your app:

```bash
npm run build
```

You can preview the production build with `npm run preview`.

> To deploy your app, you may need to install an [adapter](https://svelte.dev/docs/kit/adapters) for your target environment.
