local_UID=$(id -u $USER)
local_GID=$(id -g $USER)

echo 'start'
sudo chown ${local_UID}:${local_GID} * -R
echo '======================'
sudo chown ${local_UID}:${local_GID} .* -R
echo 'end'
