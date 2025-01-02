#!/command/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Home Assistant Community Add-on: Tailscale
# S6 Overlay stage2 hook to customize services
# ==============================================================================

declare options
declare proxy funnel proxy_and_funnel_port

# Upgrade configuration from 'proxy', 'funnel' and 'proxy_and_funnel_port' to 'share_homeassistant' and 'share_on_port'
# This step can be removed in a later version
options=$(bashio::addon.options)
proxy=$(bashio::jq "${options}" '.proxy')
funnel=$(bashio::jq "${options}" '.funnel')
proxy_and_funnel_port=$(bashio::jq "${options}" '.proxy_and_funnel_port')
# Ugrade to share_homeassistant
if bashio::var.true "${proxy}"; then
    if bashio::var.true "${funnel}"; then
        bashio::addon.option 'share_homeassistant' 'funnel'
    else
        bashio::addon.option 'share_homeassistant' 'serve'
    fi
fi
# Ugrade to share_on_port
if ! bashio::var.equals "${proxy_and_funnel_port}" 'null'; then
    bashio::addon.option 'share_on_port' "${proxy_and_funnel_port}"
fi
# Remove previous options
if ! bashio::var.equals "${proxy}" 'null'; then
    bashio::addon.option 'proxy'
fi
if ! bashio::var.equals "${funnel}" 'null'; then
    bashio::addon.option 'funnel'
fi
if ! bashio::var.equals "${proxy_and_funnel_port}" 'null'; then
    bashio::addon.option 'proxy_and_funnel_port'
fi

# Disable protect-subnets service when userspace-networking is enabled or accepting routes is disabled
if ! bashio::config.has_value "userspace_networking" || \
    bashio::config.true "userspace_networking" || \
    bashio::config.false "accept_routes";
then
    rm /etc/s6-overlay/s6-rc.d/user/contents.d/protect-subnets
    rm /etc/s6-overlay/s6-rc.d/post-tailscaled/dependencies.d/protect-subnets
fi

# Disable mss-clamping service when userspace-networking is enabled
if ! bashio::config.has_value "userspace_networking" || \
    bashio::config.true "userspace_networking";
then
    rm /etc/s6-overlay/s6-rc.d/user/contents.d/mss-clamping
fi

# Disable taildrop service when it has been explicitly disabled
if bashio::config.false 'taildrop'; then
    rm /etc/s6-overlay/s6-rc.d/user/contents.d/taildrop
fi

# Disable share-homeassistant service when share_homeassistant has not been explicitly enabled
if ! bashio::config.has_value 'share_homeassistant' || \
    bashio::config.equals 'share_homeassistant' 'disabled'
then
    rm /etc/s6-overlay/s6-rc.d/user/contents.d/share-homeassistant
fi

# Disable certificate service when it has not been configured
if ! bashio::config.has_value 'share_homeassistant' || \
    bashio::config.equals 'share_homeassistant' 'disabled' || \
    ! bashio::config.has_value 'lets_encrypt_certfile' || \
    ! bashio::config.has_value 'lets_encrypt_keyfile';
then
    rm /etc/s6-overlay/s6-rc.d/user/contents.d/certificate
fi
