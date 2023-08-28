import React from 'react';
import PropTypes from 'prop-types';
import cx from 'classnames';

export const TooltipArrowPositions = Object.freeze({
  top: 'top',
  topLeft: 'top-left',
  topRight: 'top-right',
  bottom: 'bottom',
  bottomLeft: 'bottom-left',
  bottomRight: 'bottom-right',
  left: 'left',
  leftTop: 'left-top',
  leftBottom: 'left-bottom',
  right: 'right',
  rightTop: 'right-top',
  rightBottom: 'right-bottom',
});

const Tooltip = ({ children, arrowPosition, small }) => {
  const tooltipClasses = cx(
    'maxio-tooltip',
    {
      'maxio-tooltip--small': small,
      [`maxio-tooltip--arrow-${arrowPosition}`]: arrowPosition,
    },
  );

  return (
    <div className={tooltipClasses} role="tooltip" >
      <div className="maxio-tooltip__content">
        {children}
      </div>
    </div>
  );
};

Tooltip.defaultProps = {
  withArrow: true,
  small: true,
};

Tooltip.propTypes = {
  small: PropTypes.bool,
  arrowPosition: PropTypes.oneOf(Object.values(TooltipArrowPositions)),
  children: PropTypes.any,
};

export default Tooltip;
