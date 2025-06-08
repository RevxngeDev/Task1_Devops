# DevOps Assignment 1 - Bash Scripting

The script `devops_task1.sh` implements:

1. **Group Management**:
   - Creates `dev` group if it doesn't exist
   - Adds all non-system users (UID ≥ 1000) with login shells to the group

2. **Sudo Configuration**:
   - Adds `%dev ALL=(ALL) NOPASSWD:ALL` to `/etc/sudoers`

3. **Directory Creation**:
   - Creates directories in the specified/prompted location
   - Follows naming pattern `<username>_workdir`
   - Sets proper ownership and permissions
   - Uses ACL to grant read access to `dev` group

4. **Error Handling**:
   - Validates target directory existence
   - Handles permission issues gracefully
   - Logs all operations and errors

5. **Logging**:
   - Outputs to both console and `/var/log/devops_task.log`

## Usage

```bash
# Make the script executable
chmod +x devops_task1.sh

# Run with target directory specified
sudo ./devops_task1.sh -d /path/to/target

# Run without target directory (will prompt)
sudo ./devops_task1.sh
