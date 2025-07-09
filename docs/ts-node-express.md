# TypeScript / Node / Express / Valkey Framework

For using Valkey as a backing database in your TypeScript, Express, and Node.js project, one of the best and most popular client libraries is **iovalkey**. Here are some reasons why iovalkey is a great choice, along with a brief overview of how to set it up:

### Why Choose iovalkey?

1. **Performance**: iovalkey is known for its high performance and efficiency, making it suitable for production environments.

2. **Support for Clustering**: It has built-in support for Valkey clustering, allowing you to work with Valkey in a distributed setup.

3. **Promise-based API**: iovalkey supports both callback and promise-based APIs, making it easy to work with asynchronous code in Node.js.

4. **TypeScript Support**: iovalkey has excellent TypeScript definitions, providing type safety and autocompletion in your TypeScript projects.

5. **Rich Feature Set**: It supports all Valkey commands and features, including pub/sub, transactions, and Lua scripting.

### Setting Up iovalkey

Here’s how to set up iovalkey in your TypeScript/Express/Node.js project:

1. **Install iovalkey**:
   You can install iovalkey using npm:
   ```bash
   npm install iovalkey
   ```

2. **Install Type Definitions** (if needed):
   iovalkey comes with built-in TypeScript definitions, so you typically don't need to install additional types. However, if you encounter any issues, you can install the types:
   ```bash
   npm install --save-dev @types/iovalkey
   ```

3. **Using iovalkey in Your Application**:
   Here’s a simple example of how to use iovalkey in your Express application:

   ```typescript
   // src/app.ts
   import express from 'express';
   import Valkey from 'iovalkey'; // redis clone
   import { config { from './config';

   const app = express();
   const valkey = new Valkey({
       host: config.valkeyHost,
       port: config.valkeyPort,
   }); // Connect to Valkey server

   app.get('/set/:key/:value', async (req, res) => {
     const { key, value } = req.params;
     await valkey.set(key, value);
     res.send(`Set ${key} = ${value}`);
   });

   app.get('/get/:key', async (req, res) => {
     const { key } = req.params;
     const value = await valkey.get(key);
     res.send(`Value for ${key} is ${value}`);
   });

   const PORT = process.env.PORT || 3000;
   app.listen(PORT, () => {
     console.log(`Server is running on http://localhost:${PORT}`);
   });
   ```

4. **Run Your Application**:
   Make sure your Valkey server is running, and then start your Express application:
   ```bash
   npm run start
   ```

### Conclusion

Using **iovalkey** as your Valkey client library in a TypeScript, Express, and Node.js project is a great choice due to its performance, feature set, and TypeScript support. It allows you to easily interact with Valkey and leverage its capabilities in your application.

###### dpw | 2025.07.09 | 81WBv4C8rODZ
