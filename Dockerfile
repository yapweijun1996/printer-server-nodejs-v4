# Use an official Node.js runtime as a parent image
# We choose a version that includes npm and is stable.
FROM node:18-slim

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the package.json and package-lock.json to leverage Docker's build cache.
# This step is only re-run when these files change.
COPY package*.json ./

# Install app dependencies
RUN npm install

# Install pm2 globally within the container
RUN npm install pm2 -g

# Copy the rest of the application's source code from the host to the image filesystem.
COPY . .

# Make port 3000 available to the world outside this container
EXPOSE 3000

# Define the command to run the app using PM2.
# This will start the server defined in the ecosystem.config.cjs file.
CMD [ "pm2-runtime", "start", "ecosystem.config.cjs", "--env", "production" ]